import { companies } from '../config/db';
import { Company } from '../models/company.model';
import { ApiError } from '../utils/api-error';

const projection = { _id: 0 } as const;

export async function createCompany(input: Partial<Company>): Promise<Company> {
  if (!input.id) throw new ApiError(400, 'id is required');
  if (!input.name) throw new ApiError(400, 'name is required');

  const existing = await companies().findOne({ id: input.id });
  if (existing) throw new ApiError(409, 'A company with this id already exists');

  const doc: Company = {
    id: input.id,
    name: input.name,
    address: input.address,
    createdAt: Date.now(),
  };

  await companies().insertOne(doc);
  return getCompany(doc.id);
}

export async function listCompanies(): Promise<Company[]> {
  return companies().find({}, { projection }).toArray();
}

export async function getCompany(id: string): Promise<Company> {
  const company = await companies().findOne({ id }, { projection });
  if (!company) throw new ApiError(404, 'Company not found');
  return company;
}

export async function updateCompany(id: string, updates: Partial<Company>): Promise<Company> {
  const set: Partial<Company> = {};
  if (updates.name !== undefined) set.name = updates.name;
  if (updates.address !== undefined) set.address = updates.address;

  const result = await companies().findOneAndUpdate(
    { id },
    { $set: { ...set, updatedAt: new Date() } },
    { returnDocument: 'after', projection },
  );

  if (!result) throw new ApiError(404, 'Company not found');
  return result;
}

export async function deleteCompany(id: string): Promise<void> {
  const result = await companies().deleteOne({ id });
  if (result.deletedCount === 0) throw new ApiError(404, 'Company not found');
}
